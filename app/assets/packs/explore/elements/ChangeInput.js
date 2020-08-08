

import React from 'react'

const ChangeInput = ({
  type = 'text',
  className = 'inline-input',
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
      value={value}
      {...props}
    /><span>{addon}</span>
  </span>)
}

export default ChangeInput

