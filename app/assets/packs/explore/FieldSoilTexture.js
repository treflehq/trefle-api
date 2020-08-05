
import React from 'react'
import { range } from 'lodash'
import clsx from 'clsx'
import Scale from './Scale'
import UnknownItem from './Unknown'

const FieldSoilTexture = ({ value }) => {

  if (value === null || value === undefined) {
    return <p>
      <b>Soil texture:</b>{' '}<UnknownItem value={value} name={'soil_texture'} />
    </p>
  }

  const legend = {
    1: 'Clay',
    2: 'Intermediate',
    3: 'Silt',
    4: 'Fine sand',
    5: 'Coarse sand',
    6: 'Gravel',
    7: 'Pebbles, rockeries',
    8: 'Blocks, slabs, rocky flats',
    9: 'Vertical cracks in the walls'
  }

  return (
    <div className="columns">
      <div className="column is-9">
        <p>
          <b>Soil texture:</b>
          {' '}
          {legend[value]}
        </p>
      </div>
      <div className="column is-3">
        <Scale min={1} max={9} value={value} leftIcon={'dot-circle'} rightIcon={'scrubber'} />
      </div>
    </div>
  )
}

export default FieldSoilTexture