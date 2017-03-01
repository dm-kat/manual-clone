package redis

import (
	"sync"
	"testing"
	"time"

	"github.com/rafaeljusto/redigomock"
	"github.com/stretchr/testify/assert"
)

const (
	runnerKey = "runner:build_queue:10"
)

func createSubscriptionMessage(key, data string) []interface{} {
	return []interface{}{
		[]byte("message"),
		[]byte(key),
		[]byte(data),
	}
}

func createSubscribeMessage(key string) []interface{} {
	return []interface{}{
		[]byte("subscribe"),
		[]byte(key),
		[]byte("1"),
	}
}
func createUnsubscribeMessage(key string) []interface{} {
	return []interface{}{
		[]byte("unsubscribe"),
		[]byte(key),
		[]byte("1"),
	}
}

func countWatchers(key string) int {
	keyWatcherMutex.Lock()
	defer keyWatcherMutex.Unlock()
	return len(keyWatcher[key])
}

func deleteWatchers(key string) {
	keyWatcherMutex.Lock()
	defer keyWatcherMutex.Unlock()
	delete(keyWatcher, key)
}

// Forces a run of the `Process` loop against a mock PubSubConn.
func processMessages(numWatchers int, value string) {
	psc := redigomock.NewConn()

	// Setup the initial subscription message
	psc.Command("SUBSCRIBE", keySubChannel).Expect(createSubscribeMessage(keySubChannel))
	psc.Command("UNSUBSCRIBE", keySubChannel).Expect(createUnsubscribeMessage(keySubChannel))
	psc.AddSubscriptionMessage(createSubscriptionMessage(keySubChannel, runnerKey+"="+value))

	// Wait for all the `WatchKey` calls to be registered
	for countWatchers(runnerKey) != numWatchers {
		time.Sleep(time.Millisecond)
	}

	processInner(psc)
}

func TestWatchKeySeenChange(t *testing.T) {
	conn, td := setupMockPool()
	defer td()

	conn.Command("GET", runnerKey).Expect("something")

	wg := &sync.WaitGroup{}
	wg.Add(1)

	go func() {
		val, err := WatchKey(runnerKey, "something", time.Second)
		assert.NoError(t, err, "Expected no error")
		assert.Equal(t, WatchKeyStatusSeenChange, val, "Expected value to change")
		wg.Done()
	}()

	processMessages(1, "somethingelse")
	wg.Wait()
}

func TestWatchKeyNoChange(t *testing.T) {
	conn, td := setupMockPool()
	defer td()

	conn.Command("GET", runnerKey).Expect("something")

	wg := &sync.WaitGroup{}
	wg.Add(1)

	go func() {
		val, err := WatchKey(runnerKey, "something", time.Second)
		assert.NoError(t, err, "Expected no error")
		assert.Equal(t, WatchKeyStatusNoChange, val, "Expected notification without change to value")
		wg.Done()
	}()

	processMessages(1, "something")
	wg.Wait()

}

func TestWatchKeyTimeout(t *testing.T) {
	conn, td := setupMockPool()
	defer td()

	conn.Command("GET", runnerKey).Expect("something")

	val, err := WatchKey(runnerKey, "something", time.Millisecond)
	assert.NoError(t, err, "Expected no error")
	assert.Equal(t, WatchKeyStatusTimeout, val, "Expected value to not change")

	// Clean up watchers since Process isn't doing that for us (not running)
	deleteWatchers(runnerKey)
}

func TestWatchKeyAlreadyChanged(t *testing.T) {
	conn, td := setupMockPool()
	defer td()

	conn.Command("GET", runnerKey).Expect("somethingelse")

	val, err := WatchKey(runnerKey, "something", time.Second)
	assert.NoError(t, err, "Expected no error")
	assert.Equal(t, WatchKeyStatusAlreadyChanged, val, "Expected value to have already changed")

	// Clean up watchers since Process isn't doing that for us (not running)
	deleteWatchers(runnerKey)
}

func TestWatchKeyMassivelyParallel(t *testing.T) {
	runTimes := 100 // 100 parallel watchers

	conn, td := setupMockPool()
	defer td()

	wg := &sync.WaitGroup{}
	wg.Add(runTimes)

	getCmd := conn.Command("GET", runnerKey)

	for i := 0; i < runTimes; i++ {
		getCmd = getCmd.Expect("something")
	}

	for i := 0; i < runTimes; i++ {
		go func() {
			val, err := WatchKey(runnerKey, "something", time.Second)
			assert.NoError(t, err, "Expected no error")
			assert.Equal(t, WatchKeyStatusSeenChange, val, "Expected value to change")
			wg.Done()
		}()
	}

	processMessages(runTimes, "somethingelse")
	wg.Wait()
}
