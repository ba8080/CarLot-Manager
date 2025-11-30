import unittest
from unittest.mock import patch, MagicMock
import sys
import os

# Add app directory to path so we can import functions
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'app')))

import functions

class TestCarLotFunctions(unittest.TestCase):

    def setUp(self):
        self.inventory = [
            {"id": 1, "brand": "Toyota", "model": "Corolla", "year": 2018, "buy_price": 12000.0, "sell_price": None, "is_sold": False},
            {"id": 2, "brand": "Honda", "model": "Civic", "year": 2019, "buy_price": 14000.0, "sell_price": 15000.0, "is_sold": True}
        ]

    @patch('builtins.input', side_effect=['3', 'Ford', 'Focus', '2020', '10000'])
    @patch('storage.save_inventory')
    @patch('builtins.print')
    def test_add_car_success(self, mock_print, mock_save, mock_input):
        functions.add_car(self.inventory)
        self.assertEqual(len(self.inventory), 3)
        self.assertEqual(self.inventory[2]['brand'], 'Ford')
        mock_save.assert_called()

    @patch('builtins.input', side_effect=['1'])
    @patch('storage.save_inventory')
    @patch('builtins.print')
    def test_add_car_duplicate_id(self, mock_print, mock_save, mock_input):
        functions.add_car(self.inventory)
        self.assertEqual(len(self.inventory), 2)
        mock_save.assert_not_called()

    @patch('builtins.input', side_effect=['1'])
    @patch('storage.save_inventory')
    @patch('builtins.print')
    def test_remove_car_success(self, mock_print, mock_save, mock_input):
        functions.remove_car(self.inventory)
        self.assertEqual(len(self.inventory), 1)
        self.assertEqual(self.inventory[0]['id'], 2)
        mock_save.assert_called()

    @patch('builtins.input', side_effect=['99'])
    @patch('storage.save_inventory')
    @patch('builtins.print')
    def test_remove_car_not_found(self, mock_print, mock_save, mock_input):
        functions.remove_car(self.inventory)
        self.assertEqual(len(self.inventory), 2)
        mock_save.assert_not_called()

    @patch('builtins.input', side_effect=['1', '13000'])
    @patch('storage.save_inventory')
    @patch('builtins.print')
    def test_sell_car_success(self, mock_print, mock_save, mock_input):
        functions.sell_car(self.inventory)
        self.assertTrue(self.inventory[0]['is_sold'])
        self.assertEqual(self.inventory[0]['sell_price'], 13000.0)
        mock_save.assert_called()

    @patch('builtins.input', side_effect=['2'])
    @patch('storage.save_inventory')
    @patch('builtins.print')
    def test_sell_car_already_sold(self, mock_print, mock_save, mock_input):
        functions.sell_car(self.inventory)
        # Should not change anything
        self.assertEqual(self.inventory[1]['sell_price'], 15000.0)
        mock_save.assert_not_called()

if __name__ == '__main__':
    unittest.main()
