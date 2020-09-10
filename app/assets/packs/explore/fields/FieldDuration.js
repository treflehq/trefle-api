
import React from 'react'
import UnknownItem from './Unknown'
import CorrectionContext from '../CorrectionContext'
import ChangeInputSelect from '../elements/ChangeInputSelect'
import { useContext } from 'react'
import { durations } from '../constants/constants'
import { firstNotNil } from '../utils/utils'

const FieldDuration = ({
  value,
  name = 'duration'
}) => {
  const { edit, correction, setField } = useContext(CorrectionContext)

  if (edit) {
    return (<ChangeInputSelect
      options={durations}
      multiple
      placeholder='durations...'
      onChange={(e) => setField(name, e)}
      value={firstNotNil(correction[name], value)}
    />)
  }

  return <span>
    <UnknownItem value={value} name={name} />
  </span>
}

export default FieldDuration