import posixpath
from unittest import TestCase

from freezegun import freeze_time

from mock import patch, MagicMock

from contentstore import ContentStore


# Override os.path with posix-version, to be OS-agnostic
@patch('contentstore.os.path', new=posixpath)
class TestContentStore(TestCase):
    @patch('contentstore.os.makedirs')
    @patch('contentstore.os.stat')
    def test_save_file_object(self, mock_os_stat, mock_os_makedirs):
        # Arrange
        cs = ContentStore()

        mock_os_stat.side_effect = OSError

        mockfile = MagicMock()

        # Act
        with patch.object(cs, '_get_new_file_name',
                          return_value='testfile.bin'), \
                patch.object(cs, '_get_file_sub_path',
                             return_value='sub/path/'), \
                patch('contentstore.FILE_UPLOAD_FOLDER',
                      new='/test/'):
            actual_result = cs.save_file_object(mockfile)

        # Assert
        mockfile.save.assert_called_with('/test/sub/path/testfile.bin')
        self.assertEqual('store:sub/path/testfile.bin', actual_result)

    @patch('contentstore.os.removedirs')
    @patch('contentstore.os.remove')
    def test_remove(self, mock_os_remove, mock_os_removedirs):
        # Arrange
        cs = ContentStore()

        # Act
        with patch.object(cs, 'get_filename_for_url', new=lambda x: x):
            cs.remove('a/test/url')

        # Assert
        mock_os_remove.assert_called_with('a/test/url')
        mock_os_removedirs.assert_called_with('a/test')

    def test_get_new_file_name(self):
        # Arrange
        cs = ContentStore()

        uuid = 'e7bc6d44-51fb-4562-9df6-abe8f7f75e00'
        expected_result = '{}.bin'.format(uuid)

        # Act
        with patch('contentstore.uuid.uuid4', return_value=uuid):
            actual_result = cs._get_new_file_name()

        # Assert
        self.assertEqual(expected_result, actual_result)

    @freeze_time("2010-01-01")
    def test_get_file_sub_path(self):
        # Arrange
        cs = ContentStore()
        expected_result = '2010/01/01/00/00'

        # Act
        actual_result = cs._get_file_sub_path()

        # Assert
        self.assertEqual(expected_result, actual_result)

    def test_get_filename_for_url(self):
        # Arrange
        cs = ContentStore()
        expected_result = '/test/url'

        # Act

        with patch('contentstore.FILE_UPLOAD_FOLDER', new='/test/'):
            actual_result = cs.get_filename_for_url('store:url')

        # Assert
        self.assertEqual(expected_result, actual_result)

    def test_get_filename_for_url_raises_on_wrong_scheme(self):
        # Arrange
        cs = ContentStore()

        # Act

        with patch('contentstore.FILE_UPLOAD_FOLDER',
                   new='/test/'), self.assertRaises(Exception):
            cs.get_filename_for_url('bla:url')
