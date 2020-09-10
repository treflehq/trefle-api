
import React from 'react'
import UnknownItem from './Unknown'
import CorrectionContext from '../CorrectionContext'
import ChangeInputSelect from '../elements/ChangeInputSelect'
import { useContext } from 'react'
import { colors } from '../constants/constants'
import { firstNotNil } from '../utils/utils'

const FieldColor = ({
  value,
  name
}) => {
  const { edit, correction, setField } = useContext(CorrectionContext)


  if (edit) {
    return (<ChangeInputSelect
      options={colors}
      multiple
      placeholder='colors...'
      onChange={(e) => setField(name, e)}
      value={firstNotNil(correction[name], value)}
    />)
  }

  return <span>
    <UnknownItem value={value} name={name} mapping={colors} />
  </span>
}

export default FieldColor