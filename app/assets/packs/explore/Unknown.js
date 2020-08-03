
import React from 'react'

const UnknownItem = ({ value, name }) => {

  return (<span key={name} className="unknownItem">
    unknown
  </span>)
}

export default UnknownItem