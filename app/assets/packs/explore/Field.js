
import React from 'react'
import UnknownItem from './Unknown'

const Field = ({
  value,
  name,
  children,
  Component
}) => {

  const renderValue = () => {
    if (children) {
      return children
    } else if (Component) {
      return <Component value={value} />
    } else {
      return value
    }
  }
  return (<span className="fieldItem">
    {value ? renderValue() : <UnknownItem value={value} name={name}/> }
  </span>)
}

export default Field