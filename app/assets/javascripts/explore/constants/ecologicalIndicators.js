// The Ellenberg-type classes behind light, humidity, nutriments and
// salinity, as the page ships them: config/ecological_indicators.yml,
// serialized on the data attribute of #explore-species-page. One vocabulary
// for the React fields and the server-rendered pages: a class reads
// "7 / 9 · half-light to light", never a lux or µg/l figure.
import { memoize } from 'lodash'

const EMPTY = { note: null, indicators: {} }

const read = memoize(() => {
  const container = document.querySelector('#explore-species-page')
  const raw = container && container.dataset.ecologicalIndicators
  if (!raw) return EMPTY
  try {
    return JSON.parse(raw)
  } catch (e) {
    return EMPTY
  }
})

export const indicatorNote = () => read().note

export const indicator = (name) => read().indicators[name]

// Display strings keyed to their class number, the shape UnknownItem,
// MappedValue and the edit range already expect:
// { '7 / 9 · half-light to light': 7, ... }
export const indicatorOptions = (spec) => {
  const options = {}
  Object.keys(spec.classes).forEach(key => {
    const klass = parseInt(key, 10)
    options[`${klass} / ${spec.max} · ${spec.classes[key]}`] = klass
  })
  return options
}
