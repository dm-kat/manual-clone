import GeoNodesStore from 'ee/geo_nodes/store/geo_nodes_store';

import {
  mockNodes,
  rawMockNodeDetails,
  mockNodeDetails,
  MOCK_REPLICABLE_TYPES,
} from '../mock_data';

describe('GeoNodesStore', () => {
  let store;

  beforeEach(() => {
    store = new GeoNodesStore(
      mockNodeDetails.primaryVersion,
      mockNodeDetails.primaryRevision,
      MOCK_REPLICABLE_TYPES,
    );
  });

  describe('constructor', () => {
    it('initializes default state', () => {
      expect(typeof store.state).toBe('object');
      expect(Array.isArray(store.state.nodes)).toBeTruthy();
      expect(typeof store.state.nodeDetails).toBe('object');
      expect(store.state.primaryVersion).toBe(mockNodeDetails.primaryVersion);
      expect(store.state.primaryRevision).toBe(mockNodeDetails.primaryRevision);
      expect(store.state.replicableTypes).toBe(MOCK_REPLICABLE_TYPES);
    });
  });

  describe('setNodes', () => {
    it('sets nodes list to state', () => {
      store.setNodes(mockNodes);

      expect(store.getNodes()).toHaveLength(mockNodes.length);
    });
  });

  describe('setNodeDetails', () => {
    it('sets node details to state', () => {
      store.setNodeDetails(2, rawMockNodeDetails);

      expect(typeof store.getNodeDetails(2)).toBe('object');
    });
  });

  describe('removeNode', () => {
    it('removes node from store state', () => {
      store.setNodes(mockNodes);
      const nodeToBeRemoved = store.getNodes()[1];
      store.removeNode(nodeToBeRemoved);
      store.getNodes().forEach(node => {
        expect(node.id).not.toBe(nodeToBeRemoved);
      });
    });
  });

  describe('formatNode', () => {
    it('returns formatted raw node object', () => {
      const node = GeoNodesStore.formatNode(mockNodes[0]);

      expect(node.id).toBe(mockNodes[0].id);
      expect(node.url).toBe(mockNodes[0].url);
      expect(node.basePath).toBe(mockNodes[0]._links.self);
      expect(node.repairPath).toBe(mockNodes[0]._links.repair);
      expect(node.nodeActionActive).toBe(false);
    });
  });

  describe('formatNodeDetails', () => {
    it('returns formatted raw node details object', () => {
      const nodeDetails = GeoNodesStore.formatNodeDetails(
        rawMockNodeDetails,
        store.state.replicableTypes,
      );

      expect(nodeDetails.healthStatus).toBe(rawMockNodeDetails.health_status);
      expect(nodeDetails.replicationSlotWAL).toBe(
        rawMockNodeDetails.replication_slots_max_retained_wal_bytes,
      );

      const syncStatusNames = nodeDetails.syncStatuses.map(({ namePlural }) => namePlural);
      const replicableTypesNames = store.state.replicableTypes.map(({ namePlural }) => namePlural);

      expect(syncStatusNames).toEqual(replicableTypesNames);
    });
  });
});
