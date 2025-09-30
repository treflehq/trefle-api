
import React from 'react'
import UnknownItem from './Unknown'
import CorrectionContext from '../CorrectionContext'
import ChangeInput from '../elements/ChangeInput'
import { useContext } from 'react'
import { firstNotNil } from '../utils/utils'

const FieldHeightAverage = ({
  value,
  name = 'average_height',
  unit = 'cm'
}) => {
  const { edit, correction, setFields } = useContext(CorrectionContext)
  const realValue = firstNotNil(correction[`${name}_value`], value)

  const onChange = (v) => {
    setFields({
      [`${name}_value`]: v.target.value && parseInt(v.target.value),
      [`${name}_unit`]: unit,
    })
  }

  if (edit) {
    return (<ChangeInput
      type="number"
      onChange={onChange}
      value={realValue || ''}
      addon={unit}
    />)
  }

  return <span>
    <UnknownItem value={realValue} name={name} /> {unit} average
  </span>
}

export default FieldHeightAverage