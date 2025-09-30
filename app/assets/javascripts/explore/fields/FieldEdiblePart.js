
import React from 'react'
import UnknownItem from './Unknown'
import CorrectionContext from '../CorrectionContext'
import ChangeInputSelect from '../elements/ChangeInputSelect'
import { useContext } from 'react'
import { edibleParts } from '../constants/constants'
import { firstNotNil } from '../utils/utils'

const FieldEdiblePart = ({
  value,
  name = 'edible_part'
}) => {
  const { edit, correction, setField } = useContext(CorrectionContext)

  if (edit) {
    return (<ChangeInputSelect
      options={edibleParts}
      multiple
      placeholder='edible parts...'
      onChange={(e) => setField(name, e)}
      value={firstNotNil(correction[name], value)}
    />)
  }

  return <span>
    <UnknownItem value={value} name={name} />
  </span>
}

export default FieldEdiblePart