import React from "react";

class SetOpStatus extends React.Component {
  state = { stackId: null };

  handleClick = () => {
    // if the button is click, toggle the operational status to false
    this.setToFalse();
  }

  setToFalse = () => {
    const { drizzle, drizzleState } = this.props
    const contract = drizzle.contracts.LibraryApp

    // let drizzle know we want to call the `setOperationalStatus` method
    const stackId = contract.methods["setOperatingStatus"].cacheSend(false, {
      from: drizzleState.accounts[0]
    })

    // save the `stackId` for later reference
    this.setState({ stackId })
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
      <div>
        <button onClick={this.handleClick}>False
        </button>
        <div>{this.getTxStatus()}</div>
      </div>
    )
  }
}

export default SetOpStatus
