
import React from 'react'
import UnknownItem from './Unknown'
import CorrectionContext from '../CorrectionContext'
import ChangeInputSelect from '../elements/ChangeInputSelect'
import { useContext } from 'react'
import { foliageTextures } from '../constants/constants'

const FieldFoliageTexture = ({
  value,
  name
}) => {
  const { edit, correction, setField } = useContext(CorrectionContext)


  if (edit) {
    return (<ChangeInputSelect
      options={foliageTextures}
      placeholder='textures...'
      onChange={(e) => setField(name, e)}
      value={correction[name]}
    />)
  }

  if (value === null || value === undefined) {
    return <span>
      <UnknownItem value={value} name={name} mapping={foliageTextures} />
    </span>
  }

  return (<span>
    {value}
  </span>)
}

export default FieldFoliageTexture