import React from "react";

class ReadOpStatus extends React.Component {
  state = { dataKey: null }

  componentDidMount() {
    const { drizzle } = this.props
    const contract = drizzle.contracts.LibraryApp

    // let drizzle know we want to watch the `operational` method
    const dataKey = contract.methods["operational"].cacheCall()

    // save the `dataKey` to local component state for later reference
    this.setState({ dataKey })
  }

  render() {
    // get the contract state from drizzleState
    const { LibraryApp } = this.props.drizzleState.contracts

    // using the saved `dataKey`, get the variable we're interested in
    console.log(LibraryApp)
    const operational = LibraryApp.operational[this.state.dataKey]

    // if it exists, then we display its value
    return <p>LibraryApp contract operational status: {operational && operational.value.toString()}</p>
  }
}

export default ReadOpStatus;
