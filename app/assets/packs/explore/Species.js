
import { map, capitalize, keys } from 'lodash';
import React, { useContext } from 'react'
import ReactIntense from 'react-intense'
import Field from './fields/Field'
import ColorBadge from './elements/ColorBadge'
import Calendar from './elements/Calendar';
import UnknownItem from './fields/Unknown';
import ReactMarkdown from 'react-markdown'
import FieldLight from './fields/FieldLight';
import FieldAtmosphericHumidity from './fields/FieldAtmosphericHumidity';
import FieldPh from './fields/FieldPh';
import FieldPrecipitations from './fields/FieldPrecipitations';
import FieldSoilHumidity from './fields/FieldSoilHumidity';
import FieldSoilNutriments from './fields/FieldSoilNutriments';
import FieldSoilSalinity from './fields/FieldSoilSalinity';
import FieldSoilTexture from './fields/FieldSoilTexture';
import FieldTemperature from './fields/FieldTemperature';
import CorrectionContext from './CorrectionContext';
import FieldHeightAverage from './fields/FieldHeightAverage';
import FieldGrowthHabit from './fields/FieldGrowthHabit';
import FieldDuration from './fields/FieldDuration';
import FieldConspicuous from './fields/FieldConspicuous';
import FieldColor from './fields/FieldColor';
import FieldFoliageTexture from './fields/FieldFoliageTexture';
import FieldLeafRetention from './fields/FieldLeafRetention';
import clsx from 'clsx';

const Species = ({ species }) => {
  const { toggleEdit, correction, edit } = useContext(CorrectionContext)


  const renderSpecifications = () => {

    const { duration, specifications, flower, foliage, fruit_or_seed } = species

    const {
      growth_habit, average_height, maximum_height
    } = specifications

    const flowerFields = [
      <FieldConspicuous value={flower.conspicuous} key='flower_conspicuous' name="flower_conspicuous" />,
      renderColor('flower_color', flower.color)
    ].filter(e => e).reduce((prev, curr) => [prev, ', ', curr])

    const foliageFields = [
      <FieldLeafRetention value={foliage.leaf_retention} key="leaf_retention" name="leaf_retention" />,
      <FieldFoliageTexture value={foliage.texture} key="foliage_texture" name="foliage_texture" />,
      renderColor('foliage_color', foliage.color)
    ].filter(e => e).reduce((prev, curr) => [prev, ', ', curr])

    const fruitFields = [
      <FieldConspicuous value={fruit_or_seed.conspicuous} key='fruit_conspicuous' name="fruit_conspicuous" />,
      renderColor('fruit_color', fruit_or_seed.color)
    ].filter(e => e).reduce((prev, curr) => [prev, ', ', curr])

    return (
      <section className="section content" id="specifications">
        <h2 className="title is-3 ">
          <i className="fad fa-cog has-text-success"></i> Specifications
        </h2>
        <div className="columns is-multiline">
          <div className={clsx("column", edit ? 'is-12' : 'is-6')}>
            <p><b>Height</b>:{' '}
              <FieldHeightAverage value={average_height.cm} />
            </p>
            <p><b>Growth habit</b>: <FieldGrowthHabit value={growth_habit} /></p>
            <div><b>Duration</b>: <FieldDuration value={duration} /></div>
          </div>
          <div className={clsx("column", edit ? 'is-12' : 'is-6')}>
            <div className="line"><i className="fad fa-flower" />{' '}{flowerFields}{' flowers'}</div>
            <div className="line"><i className="fad fa-leaf-maple"/>{' '}{foliageFields}{' foliage'}</div>
            <div className="line"><i className="fad fa-lemon" />{' '}{fruitFields}{' fruits'}</div>
          </div>
        </div>
      </section>
    )
  }

  const renderColor = (name, value) => {
    return <FieldColor key={name} value={value} name={name} />
  }

  const renderGrowing = () => {
    const { growth } = species

    return (<section className="section content" id="growth">
      <h2 className="title is-3 ">
        <i className="fad fa-seedling has-text-success"></i> Growing
      </h2>
      { growth.description && <ReactMarkdown source={growth.description} /> }
      <FieldLight name={'light'} value={growth.light} />
      <FieldAtmosphericHumidity value={growth.atmospheric_humidity} />
      <FieldPh min={growth.ph_minimum} max={growth.ph_maximum} />
      <FieldPrecipitations min={growth.minimum_precipitation && growth.minimum_precipitation.mm} max={growth.maximum_precipitation && growth.maximum_precipitation.mm} />
      <FieldTemperature min={growth.minimum_temperature && growth.minimum_temperature.deg_c} max={growth.maximum_temperature && growth.maximum_temperature.deg_c} />

      <br />
      <h4 className="title is-5 ">
        Soil
      </h4>
      <FieldSoilHumidity value={growth.soil_humidity} />
      <FieldSoilNutriments value={growth.soil_nutriments} />
      <FieldSoilSalinity value={growth.soil_salinity} />
      <FieldSoilTexture value={growth.soil_texture} />

      <br />
      <h4 className="title is-5 ">
        Calendar
      </h4>
      <Calendar bloom={growth.bloom_months} growth={growth.growth_months} fruit={growth.fruit_months} />
    </section>)
  }

  const renderImages = () => {
    
    return (
      <section className="section content" id="images">
        <h2 className="title is-3 ">
          <i className="fad fa-image has-text-success"></i> Images
        </h2>
        {map(species.images, (images, itype) => {
          if (images.length == 0) {
            return null
          }
          return (<div key={itype}>
            <br />
            <h4 className="title is-5 ">
              {capitalize(itype)}
            </h4>
            <div className="columns is-multiline">
              {images.map(i => <div key={i.id} className="column is-2">
                <ReactIntense src={i.image_url} vertical={false} moveSpeed={0} caption={i.copyright}/>
              </div>)}
            </div>
          </div>)
        })}
      </section>)
  }

  const renderDistributions = () => {

    return (
      <section className="section content" id="distribution">
        <h2 className="title is-3 ">
          <i className="fad fa-map has-text-success"></i> Distributions
          </h2>
        {map(species.distribution, (zones, itype) => {
          if (zones.length == 0) {
            return null
          }
          return (<p key={itype}>
            <b>{capitalize(itype)}</b>: { zones.join(', ') }
          </p>)
        })}
      </section>)
  }

  const renderSynonyms = () => {

    return (
      <section className="section content" id="synonyms">
        <h2 className="title is-3 ">
          <i className="fad fa-clone has-text-success"></i> Synonyms
          </h2>
        {species.synonyms.map(syn => {
          return (<div key={syn.id}>
            <p>
              <b>{syn.name}</b> {syn.author}
            </p>
          </div>)
        })}
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
            <li><a href="#specifications">Specifications</a></li>
            <li><a href="#growth">Growing</a></li>
            <li><a href="#images">Images</a></li>
            <li><a href="#distribution">Distribution</a></li>
            <li><a href="#synonyms">Synonyms</a></li>
          </ul>

          {keys(correction).length > 0 && <>
            <hr/>
            <div className="changes-panel">
              {keys(correction).length} changes
              <button className="button is-primary" onClick={toggleEdit}>Propose changes</button>
            </div>
          </>}
        </aside>
      </div>
      <div className="column is-10">
        { renderSpecifications() }
        { renderGrowing() }
        <hr />
        { renderImages() }
        <hr />
        { renderDistributions() }
        <hr />
        { renderSynonyms() }
      </div>
    </div>
    <div>
      <pre>
        <code>{JSON.stringify(correction, null, 2)}</code>
      </pre>
    </div>
  </div>)
}

export default Species