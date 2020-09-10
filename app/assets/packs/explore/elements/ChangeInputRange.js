

import React from 'react'
import { isNil } from 'lodash'

const ChangeInputRange = ({
  type = 'range',
  className = 'inline-range',
  onChange,
  value,
  addon,
  ...props
}) => {
  return (<span className="fieldItem edit">
    <input
      type={type}
      className={className}
      onChange={onChange}
      value={isNil(value) ? '' : value}
      {...props}
    /><span>{addon}</span>
  </span>)
}

export default ChangeInputRange

