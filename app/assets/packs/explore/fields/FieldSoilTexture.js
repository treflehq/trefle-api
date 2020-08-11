import React from 'react'
import Scale from '../elements/Scale'
import UnknownItem from './Unknown'
import { useContext } from 'react'
import CorrectionContext from '../CorrectionContext'
import ChangeInputRange from '../elements/ChangeInputRange'
import { firstNotNil } from '../utils/utils'
import { invert } from 'lodash'

const FieldSoilTexture = ({
  value,
  name
}) => {
  const { edit, correction, setField } = useContext(CorrectionContext)

  const options = {
    'Clay': 1,
    'Intermediate': 2,
    'Silt': 3,
    'Fine sand': 4,
    'Coarse sand': 5,
    'Gravel': 6,
    'Pebbles, rockeries': 7,
    'Blocks, slabs, rocky flats': 8,
    'Vertical cracks in the walls': 9
  }

  const realValue = firstNotNil(correction[name], value)

  if (edit) {
    return (
      <div className="columns">
        <div className="column is-12">
          <p>
            <b>Soil texture:</b>
            {' '}

            <ChangeInputRange
              min={0}
              max={9}
              onChange={(e) => setField(name, parseInt(e.target.value))}
              value={realValue}
            />

            <span>
              {' '}
              {invert(options)[realValue]}
            </span>
          </p>
        </div>
      </div>
    )
  }

  return (
    <div className="columns">
      <div className="column is-9">
        <p>
          <b>Soil texture:</b>
          {' '}
          <UnknownItem value={value} name={name} mapping={options} />
        </p>
      </div>
      <div className="column is-3">
        <Scale min={0} max={9} value={realValue} leftIcon={'dot-circle'} rightIcon={'scrubber'} />
      </div>
    </div>
  )
}

export default FieldSoilTexture