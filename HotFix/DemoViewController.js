require('DemoViewController, UIColor');
(function () {
    defineClass('DemoViewController',{
        viewWillAppear: function (animation) {
            self.navigationController().setNavigationBarHidden(true);
            self.view().setBackgroundColor(UIColor.redColor());
        },
        setupUI: function () {
            self.ORIGsetupUI();
            self.prepareNavigation();
        }
    },{})
    defineClass('SubDemoViewController', {
        viewDidLoad: function () {
            self.super().viewDidLoad();
        },
        setupUI: function () {
            self.super().setupUI();
        }
    },{})
})();
