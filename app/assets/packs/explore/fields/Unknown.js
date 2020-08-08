
import React from 'react'
import { useContext } from 'react'
import { findKey, isArray, pickBy, keys } from 'lodash'
import CorrectionContext from '../CorrectionContext'

const UnknownItem = ({ value, name, mapping = null }) => {

  const { toggleEdit, correction } = useContext(CorrectionContext)

  if (correction[name] === undefined || correction[name] === null) {
    return (<span key={name} onClick={toggleEdit} className="">
      <span className="unknownItem">unknown</span>
    </span>)
  }

  let label = correction[name]

  if (mapping) {
    if (isArray(label)) {
      label = keys(pickBy(mapping, (value, key) => label.includes(value)))
    } else {
      label = findKey(mapping, (e => e === correction[name]))
    }
  }

  console.log({ label });

  return (<span key={name} onClick={toggleEdit} className="">
    <span className="correctedItem">{`${label}`}</span>
  </span>)
}

export default UnknownItem