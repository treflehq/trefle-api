
import React from 'react'

const ColorBadge = ({
  value
}) => {

  return (<span className="colorBadgeItem">
    <span className={`colorBadge ${value}`}>{value}</span>
  </span>)
}

export default ColorBadge