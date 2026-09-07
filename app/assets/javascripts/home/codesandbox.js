
import { capitalize } from 'lodash';
import React, { useState } from 'react'
import ReactDOM from 'react-dom';
import axios from 'axios';
import { useEffect } from 'react';
import { Light as SyntaxHighlighter } from 'react-syntax-highlighter';
import json from 'react-syntax-highlighter/dist/esm/languages/hljs/json';
import http from 'react-syntax-highlighter/dist/esm/languages/hljs/http';
import monokai from 'react-syntax-highlighter/dist/esm/styles/hljs/monokai';
import { DebounceInput } from 'react-debounce-input';
import Icon from '../shared/Icon';

SyntaxHighlighter.registerLanguage('json', json);
SyntaxHighlighter.registerLanguage('http', http);

const DEFAULT_QUERY = 'Quercus';

// Matches the design system's CodeTerminal <pre> ground (#363636, Roboto
// Mono, 0.8125rem) rather than react-syntax-highlighter's own monokai bg.
const TERMINAL_CODE_STYLE = {
  background: '#363636',
  fontFamily: '"Roboto Mono", monospace',
  fontSize: '0.8125rem',
  lineHeight: 1.5,
  margin: 0,
  padding: '0.75em 1em'
};

// The horizontal result row next to the fake terminal — mirrors the design
// system's SpeciesListItem (mono italic scientific name, one line of prose).
const SpeciesItem = ({
  image_url,
  scientific_name,
  common_name,
  synonyms,
  slug,
  rank,
  family,
  author
}) => {

  return (<div className="speciesItem">
    <aside style={image_url && { backgroundImage: `url(${image_url})`}}>
      {/* <img src={image_url} alt={scientific_name}/> */}
    </aside>
    <main>
      <h2><i>{scientific_name}</i> {author ? <small>{author}</small> : ''}
        {_enableManagement ? <a href={`/management/species/${slug}`} target="_blank"><sup>⚙</sup></a>: ''}
      </h2>
      <p>
        {common_name && <span>Also called {capitalize(common_name)}.{' '}</span>}
        Is a {rank} of the <b>{family}</b> family.
      </p>
      {synonyms.length > 0 && <small>Synonyms: {synonyms.slice(0, 2).join(' or ')}</small>}
    </main>
  </div>)
}

const CodeSandbox = (props) => {

  const [query, setQuery] = useState(DEFAULT_QUERY)
  const [response, setresponse] = useState({})

  useEffect(() => {
    async function fetchData() {
      if (query && query.length > 0) {
        const r = await axios.get(`/api/v1/species/search?token=${temp_token}&q=${query}&limit=3`)
        setresponse(r.data)
      } else {
        setresponse({})
      }
    }
    fetchData()
  }, [query])

  const onQueryChange = (q) => {
    setQuery(q)
  }

  const results = response.data || []
  const cmd = `curl "https://trefle.io/api/v1/species/search?q=${query}&limit=3&token=YOUR_TOKEN"`

  return (<>
    <div className="home-search">
      <span className="home-search__icon"><Icon name="search" /></span>
      <DebounceInput
        className="home-search__input"
        minLength={2}
        type="search"
        placeholder="Search a plant, e.g. Quercus"
        onChange={e => onQueryChange(e.target.value)}
        value={query}
        debounceTimeout={300}
      />
    </div>

    <div className="home-explore-grid">
      <div className="home-explore-grid__column">
        <p className="home-explore-grid__label">JSON response</p>
        <div className="home-terminal">
          <div className="home-terminal__bar">
            <span className="home-terminal__dot home-terminal__dot--close"></span>
            <span className="home-terminal__dot home-terminal__dot--minimize"></span>
            <span className="home-terminal__dot home-terminal__dot--zoom"></span>
          </div>
          <SyntaxHighlighter language="http" style={monokai} customStyle={TERMINAL_CODE_STYLE}>
            {`$ ${cmd}`}
          </SyntaxHighlighter>
          <SyntaxHighlighter language="json" style={monokai} customStyle={{ ...TERMINAL_CODE_STYLE, maxHeight: '260px' }}>
            {JSON.stringify(response, null, 2)}
          </SyntaxHighlighter>
        </div>
      </div>

      <div className="home-explore-grid__column">
        <p className="home-explore-grid__label">{results.length} result{results.length === 1 ? '' : 's'} as displayed on trefle.io</p>
        <div className="home-explore-grid__results">
          {results.map(e => <SpeciesItem {...e} key={e.id} />)}
        </div>
        {results.length === 0 && query.length > 0 &&
          <p className="home-muted-note">No species matches this query. Browse the documentation for the full search syntax.</p>}
        <p className="home-explore-grid__links">
          <a href="/users/sign_up">Create an account to get a token</a>
          {' '}<span className="home-muted-note">or</span>{' '}
          <a href="https://docs.trefle.io">browse the documentation</a>.
        </p>
      </div>
    </div>
  </>)
}


document.addEventListener('DOMContentLoaded', () => {
  if (document.querySelectorAll("#code-sandbox").length > 0) {
    const domContainer = document.querySelector('#code-sandbox');
    ReactDOM.render(React.createElement(CodeSandbox), domContainer);
  }
})
