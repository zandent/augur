import { addCanceledOrder, removeCanceledOrder } from 'modules/orders/actions/update-order-status';
import { 
  PUBLICTRADE, 
  CANCELORDER, 
  TX_ORDER_ID, 
  TX_MARKET_ID, 
  TX_TRADE_GROUP_ID, 
  CREATEMARKET, 
  CREATECATEGORICALMARKET, 
  CREATESCALARMARKET, 
  CREATEYESNOMARKET,
  CREATE_MARKET 
} from 'modules/common/constants';
import { UIOrder } from 'modules/types';
import { convertTransactionOrderToUIOrder } from './transaction-conversions';
import { addPendingOrder, updatePendingOrderStatus, removePendingOrder } from 'modules/orders/actions/pending-orders-management';
import { ThunkDispatch } from 'redux-thunk';
import { Action } from 'redux';
import { AppState } from 'store';
import { Events, Getters, TXEventName } from '@augurproject/sdk';
import {
  addPendingData,
  removePendingData,
} from 'modules/pending-queue/actions/pending-queue-management';

export const addUpdateTransaction = (txStatus: Events.TXStatus) => (
  dispatch: ThunkDispatch<void, any, Action>,
  getState: () => AppState
) => {
  const { eventName, transaction, hash } = txStatus;
  if (transaction) {
    const methodCall = transaction.name.toUpperCase();
    switch (methodCall) {
      case PUBLICTRADE: {
        const tradeGroupId = transaction.params[TX_TRADE_GROUP_ID];
        const marketId = transaction.params[TX_MARKET_ID];
        if (!hash && eventName === TXEventName.AwaitingSigning) {
          const { marketInfos } = getState();
          const market = marketInfos[marketId];
          return addOrder(txStatus, market, dispatch);
        }
        dispatch(updatePendingOrderStatus(tradeGroupId, marketId, eventName, hash));
        if (eventName === TXEventName.Success) {
          dispatch(removePendingOrder(tradeGroupId, marketId));
        }
        break;
      }
      case CREATEMARKET:
      case CREATECATEGORICALMARKET:
      case CREATESCALARMARKET:
      case CREATEYESNOMARKET: {
        if (hash) dispatch(addPendingData(hash, CREATE_MARKET, eventName, params));
        if (hash && eventName === TXEventName.Success) {
          dispatch(removePendingData(hash, CREATE_MARKET));
        }
        break;
      }
      case CANCELORDER: {
        const orderId = transaction.params[TX_ORDER_ID];
        dispatch(addCanceledOrder(orderId, eventName));
        if (eventName === TXEventName.Success) {
          dispatch(removeCanceledOrder(orderId));
        }
        break;
      }
      default:
        return null;
    }
  }
};

function addOrder(tx: Events.TXStatus, market: Getters.Markets.MarketInfo, dispatch) {
  if (!market) return console.log(`Could not find ${market.id} to process transaction`)
  const order: UIOrder = convertTransactionOrderToUIOrder(tx.hash, tx.transaction.params, tx.eventName, market);
  if (!order) return console.log(`Could not process order to add pending order for market ${market.id}`);
  dispatch(addPendingOrder(order, market.id));
}
