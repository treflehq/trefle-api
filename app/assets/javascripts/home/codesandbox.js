
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

SyntaxHighlighter.registerLanguage('json', json);
SyntaxHighlighter.registerLanguage('http', http);


const SpeciesItem = ({
  image_url,
  scientific_name,
  common_name,
  synonyms,
  status,
  rank,
  family,
  author
}) => {

  return (<div className="speciesItem">
    <aside style={image_url && { backgroundImage: `url(${image_url})`}}>
      {/* <img src={image_url} alt={scientific_name}/> */}
    </aside>
    <main>
      <h2><i>{scientific_name}</i> {author ? <small>{author}</small> : ''}</h2>
      <p>
        {common_name && <span>Also called {capitalize(common_name)}.{' '}</span>}
        Is a {rank} of the <b>{family}</b> family.
      </p>
      {synonyms.length > 0 && <small>Synonyms: {synonyms.slice(0, 2).join(' or ')}</small>}
    </main>
  </div>)
}

const CodeSandbox = (props) => {

  const [query, setQuery] = useState('Abies alba')
  const [response, setresponse] = useState({})

  useEffect(() => {
    async function fetchData() {
      if (query && query.length > 0) {
        const r = await axios.get(`/api/v1/species/search?token=${temp_token}&q=${query}&limit=3`)
        // const json = await r.json()
        setresponse(r.data)
      }
    }
    fetchData()
  }, [query])

  const onQueryChange = (q) => {
    setQuery(q)
  }

  const codeStyle = {
    maxHeight: '380px',
    overflowY: 'hidden',
    borderRadius: '5px',
  }

  const inputStyle = {
    boxShadow: 'none',
    fontSize: '1em',
    fontFamily: '"Roboto Mono", monospace',
    border: 'none',
    color: '#42b913',
    borderRadius: '3px',
    backgroundColor: '#edf7ea',
    padding: '3px 5px',
    marginLeft: '10px',
    display: 'inline'
  }

  return (<>
    <div className="columns">
      <div className="column is-1">
        <h1 className="title has-text-centered">
          <i className="fad has-text-primary fa-code"></i>
        </h1>
      </div>
      <div className="column is-10">
        <h1 className="title">Try it !</h1>
        <h2 className=" subtitle">
          <span>
            Search for
            
            <DebounceInput
              minLength={2}
              style={inputStyle}
              type="text"
              onChange={e => onQueryChange(e.target.value)}
              value={query}
              debounceTimeout={300}
            />
          </span>
        </h2>
      </div>
    </div>
    <div className="columns">
      <div className="column is-1">
      </div>
      <div className="column is-5 code-wrap-left">
        <div className="wrapper" style={codeStyle}>
          <div className="fakeMenu">
            <div className="fakeButtons fakeClose"></div>
            <div className="fakeButtons fakeMinimize"></div>
            <div className="fakeButtons fakeZoom"></div>
          </div>
          <SyntaxHighlighter language="http" style={monokai}>
            {`$ curl trefle.io/api/v1/species/search?q=${query}&limit=3`}
          </SyntaxHighlighter>
          <SyntaxHighlighter language="json" style={monokai}>
            {JSON.stringify(response, null, 2)}
          </SyntaxHighlighter>
        </div>
      </div>
      <div className="column is-5 code-wrap-right">
        {response.data && response.data.map(e => <SpeciesItem {...e} key={e.id} />)}
      </div>
    </div>
    <div className="columns">
      <div className="column is-1">
      </div>
      <div className="column is-10">
        <p>
          <a href="/profile" >Create an account to get started</a>
          {' or '}
          <a href="https://docs.trefle.io" >Browse the docs</a>
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
