import React from 'react'
import Scale from '../elements/Scale'
import UnknownItem from './Unknown'
import { useContext } from 'react'
import CorrectionContext from '../CorrectionContext'
import ChangeInputRange from '../elements/ChangeInputRange'
import { firstNotNil } from '../utils/utils'
import { invert, reverse } from 'lodash'

const FieldSoilNutriments = ({
  value,
  name
}) => {
  const { edit, correction, setField } = useContext(CorrectionContext)

  const options = {
    'Very low (≈100 µg N / l)': 1, // hyperoligotrophiles
    'Low (≈200 µg N / l)': 2, // peroligotrophiles
    'Low (≈300 µg N / l)': 3, // oligotrophiles
    'Low (≈400 µg N / l)': 4, // méso - oligotrophiles
    'Medium (≈500 µg N / l)': 5, // mésotrophiles
    'Medium (≈750 µg N / l)': 6, // méso - eutrophiles
    'High (≈1000 µg N / l)': 7, // eutrophiles
    'High (≈1250 µg N / l)': 8, // pereutrophiles
    'Very high (≈1500 µg N / l)': 9, // hypereutrophiles
  }

  const realValue = firstNotNil(correction[name], value)

  if (edit) {
    return (
      <div className="columns">
        <div className="column is-12">
          <p>
            <b>Soil nutriments:</b>
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
          <b>Soil nutriments:</b>
          {' '}
          <UnknownItem value={value} name={name} mapping={options} />
        </p>
      </div>
      <div className="column is-3">
        <Scale min={1} max={9} value={realValue} leftIcon={'cauldron'} />
      </div>
    </div>
  )
}

export default FieldSoilNutriments