#!/usr/bin/env python
from __future__ import print_function, unicode_literals

from kivy.app import App
from kivy.clock import Clock
from kivy.properties import StringProperty
from kivy.uix.floatlayout import FloatLayout
from kivy.uix.screenmanager import Screen
from kivymd.theming import ThemeManager
from kivymd.toolbar import Toolbar

from version import __version__


class CustomToolbar(Toolbar):
    """
    Toolbar with helper method for loading default/back buttons.
    """

    def __init__(self, **kwargs):
        super(CustomToolbar, self).__init__(**kwargs)
        Clock.schedule_once(self.load_default_buttons)

    def load_default_buttons(self, dt=None):
        app = App.get_running_app()
        self.left_action_items = [
            ['menu', lambda x: app.root.navigation.toggle_nav_drawer()]]
        self.right_action_items = [[
                'dots-vertical',
                lambda x: app.root.navigation.toggle_nav_drawer()]]

    def load_back_button(self, function):
        self.left_action_items = [['arrow-left', lambda x: function()]]


class SubScreen(Screen):
    """
    Helper parent class for updating toolbar on enter/leave.
    """

    def on_back(self):
        self.manager.transition.direction = 'right'
        self.manager.current = 'roll_screen'

    def on_enter(self):
        """
        Loads the toolbar back button.
        """
        app = App.get_running_app()
        app.root.ids.toolbar_id.load_back_button(self.on_back)

    def on_leave(self):
        """
        Loads the toolbar default button.
        """
        app = App.get_running_app()
        app.root.ids.toolbar_id.load_default_buttons()


class WalletConfigScreen(SubScreen):

    def get_config(self):
        """
        Returns wallet path and encryption password user input values.
        """
        return {
            "path": self.ids.path_id.text,
            "chances": self.ids.password_id.text,
        }


class AboutScreen(SubScreen):

    project_page_property = StringProperty(
        "https://github.com/AndreMiras/EtherollApp")
    about_text_property = StringProperty()

    def __init__(self, **kwargs):
        super(AboutScreen, self).__init__(**kwargs)
        Clock.schedule_once(lambda dt: self.load_about())

    def load_about(self):
        self.about_text_property = "" + \
            "EtherollApp version: %s\n" % (__version__) + \
            "Project source code and info available on GitHub at:\n" + \
            "[color=00BFFF][ref=github]" + \
            self.project_page_property + \
            "[/ref][/color]"


class RollResultsScreen(SubScreen):
    pass


class RollScreen(Screen):

    def get_roll_input(self):
        """
        Returns bet size and chance of winning user input values.
        """
        # bet size
        bet_size = self.ids.bet_size_id
        bet_size_input = bet_size.ids.bet_size_input_id
        bet_size_value = int(bet_size_input.text)
        # chance of winning
        chance_of_winning = self.ids.chance_of_winning_id
        chances_input = chance_of_winning.ids.chances_input_id
        chances_value = int(chances_input.text)
        return {
            "bet_size": bet_size_value,
            "chances": chances_value,
        }


class Controller(FloatLayout):

    def __init__(self, **kwargs):
        super(Controller, self).__init__(**kwargs)
        Clock.schedule_once(self._after_init)

    def _after_init(self, dt):
        """
        Binds events.
        """
        roll_button = self.roll_screen.ids.roll_button_id
        roll_button.bind(on_release=lambda instance: self.roll())

    @property
    def navigation(self):
        return self.ids.navigation_id

    @property
    def roll_screen(self):
        return self.ids.roll_screen_id

    @property
    def wallet_config_screen(self):
        return self.ids.wallet_config_screen_id

    def roll(self):
        roll_input = self.roll_screen.get_roll_input()
        wallet_config = self.wallet_config_screen.get_config()
        print("roll_input:", roll_input)
        print("wallet_config:", wallet_config)


class MainApp(App):

    theme_cls = ThemeManager()

    def build(self):
        self.icon = "docs/images/icon.png"


if __name__ == '__main__':
    MainApp().run()
