
import React from 'react'
import UnknownItem from './Unknown'
import CorrectionContext from '../CorrectionContext'
import ChangeInputSelect from '../elements/ChangeInputSelect'
import { useContext } from 'react'

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

  // const options = [
  //   { label: 'Unknown', value: null },
  //   { label: 'Visible', value: true },
  //   { label: 'Invisible', value: false }
  // ]

  if (edit) {
    return (<ChangeInputSelect
      options={options}
      placeholder='visible ?'
      onChange={(e) => setField(name, e)}
      value={correction[name]}
    />)
  }

  if (value === null || value === undefined) {
    return <span>
      <UnknownItem value={value} name={name} mapping={options} />
    </span>
  }

  return (<span>
    {value}
  </span>)
}

export default FieldConspicuous