
import React, { useContext } from 'react'
import UnknownItem from './Unknown'
import CorrectionContext from '../CorrectionContext'

const Field = ({
  value,
  name,
  children,
  Component
}) => {
  const { edit, correction, setField } = useContext(CorrectionContext)

  const renderValue = () => {
    if (children) {
      return children
    } else if (Component) {
      return <Component value={value} />
    } else {
      return value
    }
  }
  if (edit) {
    return (<span className="fieldItem edit">
      <input
        type="text"
        className="input"
        onChange={(e) => setField(name, e.target.value)}
        value={`${correction[name] || ''}`}
      />
    </span>)
  } else {
    return (<span className="fieldItem">
      {value ? renderValue() : <UnknownItem value={value} name={name}/> }
    </span>)
  }
}

export default Field