extends GutTest

const TEST_PATH: String = "user://test_artdle.save"

var save: Save

func before_each():
    save = Save.new()
    save.save_path = TEST_PATH
    if FileAccess.file_exists(TEST_PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))

func after_each():
    if FileAccess.file_exists(TEST_PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
    if save != null:
        save.free()
        save = null

func test_write_and_read_roundtrip():
    var payload = {"currency": {"gold": 123.0, "fame": 5.0}}
    var ok = save.write(payload)
    assert_true(ok)
    var loaded = save.read()
    assert_true(loaded != null, "loaded should not be null")
    if loaded != null:
        assert_eq(loaded["version"], Save.SAVE_VERSION)
        assert_eq(loaded["currency"]["gold"], 123.0)

func test_read_missing_returns_null():
    assert_eq(save.read(), null)

func test_read_corrupt_returns_null():
    var f = FileAccess.open(TEST_PATH, FileAccess.WRITE)
    f.store_string("{not valid json")
    f.close()
    assert_eq(save.read(), null)

func test_version_newer_refused():
    var f = FileAccess.open(TEST_PATH, FileAccess.WRITE)
    f.store_string(JSON.stringify({"version": 999, "currency": {}}))
    f.close()
    assert_eq(save.read(), null)

func test_atomic_write_no_partial_on_failure():
    save.write({"currency": {}})
    var tmp = TEST_PATH + ".tmp"
    assert_false(FileAccess.file_exists(tmp))

func test_migrate_same_version_is_identity():
    var data = {"version": Save.SAVE_VERSION, "currency": {"gold": 1.0}}
    var migrated = save._migrate(data, Save.SAVE_VERSION, Save.SAVE_VERSION)
    assert_eq(migrated, data)
