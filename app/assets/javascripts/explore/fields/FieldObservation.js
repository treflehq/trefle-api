
import React from 'react'
import UnknownItem from './Unknown'
import CorrectionContext from '../CorrectionContext'
import { useContext } from 'react'
import { firstNotNil } from '../utils/utils'

const FieldObservation = ({
  value,
  name = 'observations'
}) => {
  const { edit, correction, setFields } = useContext(CorrectionContext)
  const realValue = firstNotNil(correction[name], value)

  const onChange = (v) => {
    setFields({
      [`${name}`]: v.target.value,
    })
  }

  if (edit) {
    return (<label className="label">
      Observations:
      <textarea
      className="textarea"
      placeholder="Observations"
      onChange={onChange}
      value={realValue || ''}
    />
    </label>)
  }

  return <span>
    <UnknownItem value={realValue} name={name} />
  </span>
}

export default FieldObservation