
import React, { useState } from 'react'
import ReactDOM from 'react-dom';
import axios from 'axios';
import { useEffect } from 'react';

const DataPage = ({ slug }) => {
  const [response, setResponse] = useState({})

  useEffect(() => {
    async function fetchData() {
      const r = await axios.get(`https://api.github.com/repos/treflehq/dump/releases`)
      setResponse(r.data)
    }
    fetchData()
  }, [])

  const renderResponse = () => {
    const lastRel = response[0]
    const asset = lastRel.assets[0]
    const size = asset && parseInt(asset.size / 1024 / 1024)
    return <div>
      <div className="field is-grouped">
        <p className="control">
          <a className="button is-primary" href={asset && asset.browser_download_url} target="_blank" rel="nofollow"><i class="fad fa-download mr-2"></i> Download csv ({size}Mo)</a>
        </p>
        <p className="control">
          <a className="button " href="https://github.com/treflehq/dump" target="_blank" rel="nofollow"><i class="fab fa-github mr-2"></i> See on Github</a>
        </p>
      </div>
      <br />
      <p><b>{lastRel.body}.</b></p>
      <p>Database archive is automatically updated after a certain amount of changes. The database archive is a tab-separated text file.</p>
    </div>
  }

  if (response[0]) {
    return renderResponse()
  } else {
    return (<div>
      <h2>Loading...</h2>
    </div>)
  }
}

document.addEventListener('DOMContentLoaded', () => {
  if (document.querySelectorAll("#species-data").length > 0) {
    const domContainer = document.querySelector('#species-data');
    ReactDOM.render(React.createElement(DataPage, {}), domContainer);
  }
})
