import React from 'react'
import Scale from '../elements/Scale'
import UnknownItem from './Unknown'
import { useContext } from 'react'
import CorrectionContext from '../CorrectionContext'
import { firstNotNil } from '../utils/utils'
import Calendar from '../elements/Calendar'

const FieldCalendar = ({
  bloom,
  growth,
  fruit
}) => {
  const { edit, correction, setField } = useContext(CorrectionContext)


  const realBloom = firstNotNil(correction['bloom_months'], bloom)
  const realGrowth = firstNotNil(correction['growth_months'], growth)
  const realFruit = firstNotNil(correction['fruit_months'], fruit)

  // @TODO
  if (edit) {
    return (
      <div className="columns">
        <div className="column is-12">
          <p className="has-text-grey">Calendar is not editable yet</p>
        </div>
      </div>
    )
  }

  return (
    <div className="columns">
      <div className="column is-12">
        <Calendar bloom={realBloom} growth={realGrowth} fruit={realFruit} />
      </div>
    </div>
  )
}

export default FieldCalendar