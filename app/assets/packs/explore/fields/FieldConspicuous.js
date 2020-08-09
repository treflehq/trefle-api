
import React from 'react'
import UnknownItem from './Unknown'
import CorrectionContext from '../CorrectionContext'
import ChangeInputSelect from '../elements/ChangeInputSelect'
import { useContext } from 'react'
import { firstNotNil } from '../utils/utils'

const FieldConspicuous = ({
  value,
  name
}) => {
  const { edit, correction, setField } = useContext(CorrectionContext)

  const options = {
    Unknown: null,
    Visible: true,
    Invisible: false
  }

  if (edit) {
    return (<ChangeInputSelect
      options={options}
      placeholder='visible ?'
      onChange={(e) => setField(name, e)}
      value={firstNotNil(correction[name], value)}
    />)
  }

  return <span>
    <UnknownItem value={value} name={name} mapping={options} />
  </span>

}

export default FieldConspicuous