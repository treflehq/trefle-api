
import React from 'react'
import UnknownItem from './Unknown'
import CorrectionContext from '../CorrectionContext'
import ChangeInput from '../elements/ChangeInput'
import { useContext } from 'react'

const FieldHeightAverage = ({
  value,
  name = 'average_height_cm'
}) => {
  const { edit, correction, setField } = useContext(CorrectionContext)

  if (edit) {
    return (<ChangeInput
      type="number"
      onChange={(e) => setField(name, e.target.value)}
      value={`${correction[name] || ''}`}
      addon={'cm'}
    />)
  }

  if (value === null || value === undefined) {
    return <span>
      <UnknownItem value={value} name={name} /> cm average
    </span>
  }

  return (<span>
    {value} cm average
  </span>)
}

export default FieldHeightAverage