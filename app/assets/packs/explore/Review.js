
import { map, capitalize, keys, omitBy, isNil, isObject, isString } from 'lodash';
import React, { useContext } from 'react'
import ReactIntense from 'react-intense'
import Field from './fields/Field'
import ColorBadge from './elements/ColorBadge'
import FieldCalendar from './fields/FieldCalendar';
import UnknownItem from './fields/Unknown';
import ReactMarkdown from 'react-markdown'
import clsx from 'clsx';
import DoneButton from './elements/DoneButton';
import CorrectionContext from './CorrectionContext';
import { useState } from 'react';
import ReferencesInput from './elements/ReferencesInput';

const Review = ({ species }) => {
  const [sourceType, setSourceType] = useState('external')
  const [sourceReference, setSourceReference] = useState([])
  const [notes, setNotes] = useState('')

  const { toggleEdit, correction, submission, edit } = useContext(CorrectionContext)

  const payload = omitBy({
    notes,
    source_type: sourceType,
    source_reference: sourceReference && sourceReference.join(', '),
    correction
  }, (e => isNil(e) || e === ''))

  const renderErrors = () => {
    if (submission && submission.error) {

      if (isObject(submission.message)) {
        return (<div className="notification is-danger is-light">
          <b>An error occured !</b>
          <ul>
            {map(submission.message, (v, k) => <li key={k}><b>{k}</b>: {v}</li>)}
          </ul>
        </div>)
      }

      if (isString(submission.message)) {
        return (<div className="notification is-danger is-light">
          <b>An error occured !</b>
          <p>{submission.message}</p>
        </div>)
      }
    } else {
      return <></>
    }
  }

  const renderSuccess = () => {
    return (
      <section className="section content" id="thanks">
        <div className="notification is-success is-light">
          <b>Thank you for your contribution !</b>
          <p>It will be reviewed shortly</p>
        </div>
        <nav className="level">
          <div className="level-left">
          </div>

          <div className="level-right">
            <p className="level-item">
              <button className="button" onClick={reset}>Back to species page</button>
            </p>
          </div>
        </nav>

      </section>)
  }

  const renderSummary = () => {
    return (
      <section className="section content" id="summary">
        {renderErrors()}
        <div className="notification is-info is-light">
          Please take a moment to review theses informations.
        </div>
        <pre>
          <code>{JSON.stringify(payload, null, 2)}</code>
        </pre>
      </section>)
  }

  const renderForm = () => {
    return (
      <section className="section content" id="infos">
        <div className="field is-horizontal">
          <div className="field-label is-normal">
            <label className="label">Source</label>
          </div>
          <div className="field-body">
            <div className="field is-narrow">
              <div className="control">
                <div className="select is-fullwidth">
                  <select className="select" value={sourceType} onChange={e => setSourceType(e.target.value)}>
                    <option value="external">External source (website, paper etc...)</option>
                    <option value="observation">Observation of a living specimen</option>
                  </select>
                </div>
              </div>
            </div>
          </div>
        </div>

        {sourceType == 'external' && <div className="field is-horizontal">
          <div className="field-label is-normal">
            <label className="label">References</label>
          </div>
          <div className="field-body">
            <div className="field">
              <div className="control">
                <ReferencesInput onChange={setSourceReference} value={sourceReference} />
              </div>
            </div>
          </div>
        </div>}

        <div className="field is-horizontal">
          <div className="field-label is-normal">
            <label className="label">Notes</label>
          </div>
          <div className="field-body">
            <div className="field">
              <div className="control">
                <textarea className="textarea" value={notes} onChange={e => setNotes(e.target.value)} placeholder="Add some additional notes to your changes"></textarea>
              </div>
            </div>
          </div>
        </div>
      </section>)
  }

  return (<div>
    <div className="columns">
      <div className="column is-4">
        <aside className="species-side-image" style={{backgroundImage: `url(${ species.image_url })`}}></aside>
      </div>
      <div className="column is-8">
        <section className="hero">
          <div className="hero-body">
            <div className="container">
              <h2 className="suptitle">
                <div className="field is-grouped is-grouped-multiline">
                  <div className="control">

                    <div className="tags has-addons">
                      <span className="tag">Status</span>
                      <span className={`tag ${species.status == 'accepted' ? 'is-primary' : ''}`}>{species.status}</span>
                    </div>
                  </div>
                  <div className="control">
                    <div className="tags has-addons">
                      <span className="tag">Rank</span>
                      <span className={`tag ${species.rank == 'species' ? 'is-primary' : 'is-info'}`}>{species.rank}</span>
                    </div>
                  </div>
                </div>
              </h2>
              <h1 className="title is-1">
                { species.scientific_name }
              </h1>
              <h2 className="subtitle">
                { species.common_name ? capitalize(species.common_name) : 'No common name' }
              </h2>
              <p className="subtitle">
                <i className="fad fa-book has-text-success"></i> { species.author || 'No author' } { species.year || 'No year' } - <i>{ species.bibliography || 'No bibliography' }</i>
              </p>
              <p className="subtitle">
                { species.observations }
              </p>
            </div>
          </div>
        </section>
      </div>
    </div>
    <div className="columns">
      <div className="column is-2">
        <br />
        <br />
        <aside className="menu">
          <ul className="menu-list sticky-menu">
            <li><a href="#infos">Source infos</a></li>
            <li><a href="#summary">Summary</a></li>
          </ul>
        </aside>
      </div>

      <div className="column is-10">

        {submission && !submission.error && submission.data && renderSuccess() || <>
          { renderForm() }
          { renderSummary() }

          <DoneButton payload={payload} />
        </>}
      </div>
    </div>
  </div>)
}

export default Review