
import React from 'react'
import { useContext } from 'react'
import CorrectionContext from '../CorrectionContext'
import { keys } from 'lodash'

const DoneButton = ({payload = null}) => {

  const { review, setReview, edit, user, reset, submitCorrection, correction } = useContext(CorrectionContext)

  const changesCount = keys(correction).length
  const hasChanges = changesCount > 0

  if (review) {
    return (<div className="done-footer">
      <nav className="level">
        <div className="level-left">
          <div className="level-item">
            <p>
              Reviewing
              {' '}
              {hasChanges ? <b>{changesCount} changes</b> : <span>no changes</span>}
              {' '}
              as {user.name || user.organization_name || 'anonymous'}
            </p>
          </div>
        </div>

        <div className="level-right">
          <p className="level-item">
            <button className="button is-danger" onClick={reset}>Cancel all changes</button>
          </p>
          <p className="level-item">
            <button disabled={!hasChanges} className="button is-primary" onClick={() => submitCorrection(payload) }>Submit</button>
          </p>
        </div>
      </nav>

    </div>)

  }

  if (edit || hasChanges) {
    return (<div className="done-footer">
      <nav className="level">
        <div className="level-left">
          <div className="level-item">
            <p>
              Editing
              {' '}
              {hasChanges ? <b>{changesCount} changes</b> : <span>no changes</span>}
              {' '}
              as {user.name || user.organization_name || 'anonymous'}
            </p>
          </div>
        </div>

        <div className="level-right">
          <p className="level-item">
            <button className="button is-danger" onClick={reset}>Cancel all changes</button>
          </p>
          <p className="level-item">
            <button disabled={!hasChanges} className="button is-primary" onClick={() => setReview(true)}>Review changes</button>
          </p>
        </div>
      </nav>

    </div>)
  } else {
    return <></>
  }
}

export default DoneButton