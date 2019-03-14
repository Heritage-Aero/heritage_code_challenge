import React from "react";

class ToggleStatus extends React.Component {
  constructor(props) {
    super(props)
    this.state = { stackId: null, isOn: true };
  }

  handleClick = () => {
    // if the button is click, toggle the operational status to false
    this.toggle();
  }

  toggle = () => {
    const { drizzle, drizzleState } = this.props
    const contract = drizzle.contracts.LibraryApp

    // let drizzle know we want to call the `setOperationalStatus` method
    const stackId = contract.methods["setOperatingStatus"].cacheSend(
      !this.state.isOn,
      { from: drizzleState.accounts[0] }
    )

    // save the `stackId` for later reference
    this.setState(state => ({ stackId: stackId, isOn: !state.isOn }))
  }

  getTxStatus = () => {
    // get the transaction states from the drizzle state
    const { transactions, transactionStack } = this.props.drizzleState

    // get the transaction hash using our saved `stackId`
    const txHash = transactionStack[this.state.stackId]

    // if transaction hash does not exist, don't display anything
    if (!txHash) return null

    // otherwise, return the transaction status
    return `Transaction status: ${transactions[txHash] && transactions[txHash].status}`
  }

  render() {
    return (
      <div className="onoffswitch">
        <input
          type="checkbox"
          name="onoffswitch"
          className="onoffswitch-checkbox"
          id="myonoffswitch"
          checked={this.state.isOn}
          onChange={this.handleClick}
        />
        <label className="onoffswitch-label" htmlFor="myonoffswitch">
          <span className="onoffswitch-inner"></span>
          <span className="onoffswitch-switch"></span>
        </label>
      </div>
    )
  }
}

export default ToggleStatus
