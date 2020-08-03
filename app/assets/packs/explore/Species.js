
import { map, capitalize } from 'lodash';
import React, { useState } from 'react'
import ReactDOM from 'react-dom';
import axios from 'axios';
import { useEffect } from 'react';
import ReactIntense from 'react-intense'
import Field from './Field'
import ColorBadge from './ColorBadge'
import Calendar from './Calendar';
import UnknownItem from './Unknown';

const Species = ({ species }) => {


  const renderSpecifications = () => {

    const { duration, specifications, flower, foliage, fruit_or_seed } = species
    
    // const { color } = flower
    // const { color } = foliage
    // const { color } = fruit_or_seed

    const {
      growth_habit, average_height, maximum_height
    } = specifications

    const flowerFields = [
      renderColor('flower_color', flower.color)
    ].filter(e => e).reduce((prev, curr) => [prev, ', ', curr])

    const foliageFields = [
      foliage.leaf_retention == null ? <UnknownItem key="leaf_retention" name="leaf_retention" /> : (foliage.leaf_retention ? 'persistent during winter' : 'not persistent'),
      foliage.texture == null ? <UnknownItem key="foliage_texture" name="foliage_texture" /> : foliage.texture,
      renderColor('foliage_color', foliage.color)
    ].filter(e => e).reduce((prev, curr) => [prev, ', ', curr])

    const fruitFields = [
      fruit_or_seed.conspicuous == null ? <UnknownItem key="1" name="fruit_conspicuous" /> : (fruit_or_seed.conspicuous ? 'visible' : 'not visible'),
      renderColor('fruit_color', fruit_or_seed.color)
    ].filter(e => e).reduce((prev, curr) => [prev, ', ', curr])

    return (
      <section className="section content" id="specifications">
        <h1 className="title is-4 ">
          <i className="fad fa-cog has-text-success"></i> Specifications
        </h1>
        <div className="columns">
          <div className="column is-6">
            <p><b><i className="fad fa-ruler-vertical" /> Height</b>:{' '}
              <Field value={average_height.cm} name={'average_height_cm'}>{average_height.cm} cm</Field>
            </p>
            <p><b>Growth habit</b>: <Field value={growth_habit} name={'growth_habit'} /></p>
            <p><b>Duration</b>: <Field value={duration} name={'duration'}>{duration && duration.join(' or ')}</Field></p>
          </div>
          <div className="column is-6">
            <p><i className="fad fa-flower" />{' '}{flowerFields}{' flowers'}</p>
            <p><i className="fad fa-leaf-maple"/>{' '}{foliageFields}{' foliage'}</p>
            <p><i className="fad fa-lemon" />{' '}{fruitFields}{' fruits'}</p>
          </div>
        </div>
      </section>
    )
  }

  const renderColor = (name, value) => {
    if (value) {
      return value.map(e => <Field key={e} value={e} Component={ColorBadge} name={name} />).reduce((prev, curr) => [prev, ' and ', curr])
    } else {
      return <UnknownItem key={name} name={name} />
    }
  }

  const renderGrowing = () => {
    const { growth } = species

    return (<section className="section content" id="growth">
      <h1 className="title is-4 ">
        <i className="fad fa-seedling has-text-success"></i> Growing
      </h1>
      <Calendar bloom={growth.bloom_months} growth={growth.growth_months} fruit={growth.fruit_months} />
    </section>)
  }

  const renderImages = () => {
    
    return (
      <section className="section content" id="images">
        <h1 className="title is-4 ">
          <i className="fad fa-image has-text-success"></i> Images
        </h1>
        {map(species.images, (images, itype) => {
          if (images.length == 0) {
            return null
          }
          return (<div key={itype}>
            <br />
            <h2 className="title is-5 ">
              {capitalize(itype)}
            </h2>
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
        <h1 className="title is-4 ">
          <i className="fad fa-map has-text-success"></i> Distributions
          </h1>
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
        <h1 className="title is-4 ">
          <i className="fad fa-clone has-text-success"></i> Synonyms
          </h1>
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
  </div>)
}

export default Species