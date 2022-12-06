
import React from 'react'
import { findKey, isArray, pickBy, keys } from 'lodash'

const MappedValue = ({ value, name, mapping = null }) => {

  let label = value

  if (mapping) {
    if (isArray(label)) {
      label = keys(pickBy(mapping, (value, key) => label.includes(value)))
    } else {
      label = findKey(mapping, (e => e === value))
    }
  }

  return (<span key={name} className="">
    <span className="valueItem">{`${label}`}</span>
  </span>)
}

export default MappedValue