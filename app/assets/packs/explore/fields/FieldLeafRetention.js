
import React from 'react'
import UnknownItem from './Unknown'
import CorrectionContext from '../CorrectionContext'
import ChangeInputSelect from '../elements/ChangeInputSelect'
import { useContext } from 'react'
import { firstNotNil } from '../utils/utils'

const FieldLeafRetention = ({
  value,
  name
}) => {
  const { edit, correction, setField } = useContext(CorrectionContext)

  const options = {
    Unknown: null,
    'Persistent during winter': true,
    'Not persistent': false
  }

  // const options = [
  //   { label: 'Unknown', value: null },
  //   { label: 'Visible', value: true },
  //   { label: 'Invisible', value: false }
  // ]

  if (edit) {
    return (<ChangeInputSelect
      options={options}
      onChange={(e) => setField(name, e)}
      value={firstNotNil(correction[name], value)}
    />)
  }

  return <span>
    <UnknownItem value={value} name={name} mapping={options} />
  </span>
}

export default FieldLeafRetention