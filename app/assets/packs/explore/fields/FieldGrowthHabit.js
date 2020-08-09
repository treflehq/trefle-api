
import React from 'react'
import UnknownItem from './Unknown'
import CorrectionContext from '../CorrectionContext'
import ChangeInput from '../elements/ChangeInput'
import { useContext } from 'react'

const FieldGrowthHabit = ({
  value,
  name = 'growth_habit'
}) => {
  const { edit, correction, setField } = useContext(CorrectionContext)

  if (edit) {
    return (<ChangeInput
      type="text"
      onChange={(e) => setField(name, e.target.value)}
      value={`${correction[name] || ''}`}
    />)
  }

  return <span>
    <UnknownItem value={value} name={name} />
  </span>
}

export default FieldGrowthHabit