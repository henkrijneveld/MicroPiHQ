<script setup>
import { onMounted, onUnmounted, ref } from 'vue'
import { t } from '../translations.js'

const props = defineProps({
  sourceElement: {
    type: Object,
    default: null,
  },
  intervalMs: {
    type: Number,
    default: 500,
  },
})

const emit = defineEmits(['sample'])
const histogramCanvas = ref(null)

const SAMPLE_WIDTH = 160
const SAMPLE_HEIGHT = 120
const HISTOGRAM_WIDTH = 256
const HISTOGRAM_HEIGHT = 96

let sampleCanvas = null
let sampleContext = null
let histogramTimer = null
let stopped = false

function drawChannel(context, bins, maximum, fillStyle, strokeStyle) {
  context.beginPath()
  context.moveTo(0, HISTOGRAM_HEIGHT)

  for (let value = 0; value < 256; value += 1) {
    const x = value
    const height = (bins[value] / maximum) * (HISTOGRAM_HEIGHT - 2)
    context.lineTo(x, HISTOGRAM_HEIGHT - height)
  }

  context.lineTo(HISTOGRAM_WIDTH - 1, HISTOGRAM_HEIGHT)
  context.closePath()
  context.fillStyle = fillStyle
  context.fill()

  context.beginPath()

  for (let value = 0; value < 256; value += 1) {
    const x = value
    const height = (bins[value] / maximum) * (HISTOGRAM_HEIGHT - 2)
    const y = HISTOGRAM_HEIGHT - height

    if (value === 0) {
      context.moveTo(x, y)
    } else {
      context.lineTo(x, y)
    }
  }

  context.strokeStyle = strokeStyle
  context.lineWidth = 1
  context.stroke()
}

function drawHistogramFromPixels(pixels) {
  const canvas = histogramCanvas.value

  if (!canvas) {
    return
  }

  const red = new Uint32Array(256)
  const green = new Uint32Array(256)
  const blue = new Uint32Array(256)
  let redTotal = 0
  let greenTotal = 0
  let blueTotal = 0

  for (let index = 0; index < pixels.length; index += 4) {
    const redValue = pixels[index]
    const greenValue = pixels[index + 1]
    const blueValue = pixels[index + 2]

    red[redValue] += 1
    green[greenValue] += 1
    blue[blueValue] += 1

    redTotal += redValue
    greenTotal += greenValue
    blueTotal += blueValue
  }

  const pixelCount = pixels.length / 4

  if (pixelCount > 0) {
    emit('sample', {
      red: redTotal / pixelCount,
      green: greenTotal / pixelCount,
      blue: blueTotal / pixelCount,
    })
  }

  let maximum = 1

  for (let value = 0; value < 256; value += 1) {
    maximum = Math.max(maximum, red[value], green[value], blue[value])
  }

  const context = canvas.getContext('2d')
  context.clearRect(0, 0, HISTOGRAM_WIDTH, HISTOGRAM_HEIGHT)
  context.fillStyle = '#ffffff'
  context.fillRect(0, 0, HISTOGRAM_WIDTH, HISTOGRAM_HEIGHT)

  drawChannel(context, blue, maximum, 'rgba(0, 90, 255, 0.32)', 'rgba(0, 70, 220, 0.95)')
  drawChannel(context, green, maximum, 'rgba(0, 180, 60, 0.32)', 'rgba(0, 145, 45, 0.95)')
  drawChannel(context, red, maximum, 'rgba(235, 30, 30, 0.32)', 'rgba(205, 20, 20, 0.95)')
}

function drawHistogramFromImage(image) {
  if (
    !sampleContext
    || !image
    || image.naturalWidth === 0
    || image.naturalHeight === 0
  ) {
    return false
  }

  sampleContext.clearRect(0, 0, SAMPLE_WIDTH, SAMPLE_HEIGHT)
  sampleContext.drawImage(image, 0, 0, SAMPLE_WIDTH, SAMPLE_HEIGHT)
  const pixels = sampleContext.getImageData(0, 0, SAMPLE_WIDTH, SAMPLE_HEIGHT).data
  drawHistogramFromPixels(pixels)
  return true
}

function drawFromLivePreview() {
  try {
    return drawHistogramFromImage(props.sourceElement)
  } catch (_) {
    return false
  }
}

function updateHistogram() {
  if (stopped || !sampleContext) {
    return
  }

  // Reuse the image already displayed by the browser; no second MJPEG connection.
  drawFromLivePreview()

  if (!stopped) {
    histogramTimer = setTimeout(updateHistogram, props.intervalMs)
  }
}

onMounted(() => {
  sampleCanvas = document.createElement('canvas')
  sampleCanvas.width = SAMPLE_WIDTH
  sampleCanvas.height = SAMPLE_HEIGHT
  sampleContext = sampleCanvas.getContext('2d', { willReadFrequently: true })

  stopped = false
  updateHistogram()
})

onUnmounted(() => {
  stopped = true

  if (histogramTimer) {
    clearTimeout(histogramTimer)
    histogramTimer = null
  }

  sampleCanvas = null
  sampleContext = null
})
</script>

<template>
  <canvas
    ref="histogramCanvas"
    class="rgb-histogram"
    :width="HISTOGRAM_WIDTH"
    :height="HISTOGRAM_HEIGHT"
    :aria-label="t('aria.rgbHistogram')"
  ></canvas>
</template>

<style scoped>
.rgb-histogram {
  display: block;
  width: 100%;
  height: 96px;
  margin-top: 6px;
  border: 1px solid var(--ui-border);
  background: #fff;
}
</style>
