# SPDX-FileCopyrightText: 2018-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

# This is commented out as we no longer use the restrictions implementation,
# but it was decided to keep for reference. Remove when restrictions.py is
# refactored.

# from unittest import TestCase
#
# from mock import patch, MagicMock
#
# from oio_rest import restrictions
#
#
# class TestRestrictions(TestCase):
#     @patch('oio_rest.restrictions.DO_ENABLE_RESTRICTIONS', new=False)
#     def test_get_restrictions_disabled(self):
#         # Arrange
#         # Act
#         actual_result = restrictions.get_restrictions('', '', '')
#
#         # Assert
#         self.assertIsNone(actual_result)
#
#     @patch('oio_rest.restrictions.DO_ENABLE_RESTRICTIONS', new=True)
#     @patch('oio_rest.restrictions.AUTH_RESTRICTION_FUNCTION',
#            new='mock_fun')
#     @patch('oio_rest.restrictions.import_module')
#     def test_get_restrictions(self, mock_import_module):
#         # type: (MagicMock) -> None
#         # Arrange
#         mock_import_module.return_value = auth_module = MagicMock()
#
#         user = 'user'
#         object_type = 'obj'
#         operation = 'op'
#
#         # Act
#         restrictions.get_restrictions(user, object_type, operation)
#
#         # Assert
#         auth_module.mock_fun.assert_called_with(user, object_type, operation)
#
#     @patch('oio_rest.restrictions.DO_ENABLE_RESTRICTIONS', new=True)
#     @patch('oio_rest.restrictions.import_module')
#     def test_get_restrictions_raises_on_attribute_error(self,
#                                                         mock_import_module):
#         # type: (MagicMock) -> None
#         # Arrange
#         mock_import_module.side_effect = AttributeError
#
#         user = 'user'
#         object_type = 'obj'
#         operation = 'op'
#
#         # Act
#         with self.assertRaises(AttributeError):
#             restrictions.get_restrictions(user, object_type, operation)
#
#     @patch('oio_rest.restrictions.DO_ENABLE_RESTRICTIONS', new=True)
#     @patch('oio_rest.restrictions.import_module')
#     def test_get_restrictions_raises_on_import_error(self, mock_import_module):
#         # type: (MagicMock) -> None
#         # Arrange
#         mock_import_module.side_effect = ImportError
#
#         user = 'user'
#         object_type = 'obj'
#         operation = 'op'
#
#         # Act
#         with self.assertRaises(ImportError):
#             restrictions.get_restrictions(user, object_type, operation)
