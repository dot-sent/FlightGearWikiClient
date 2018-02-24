"use strict";

(function(){
    var MediaWiki = require("mediawiki");

    var FGWiki = (function(){
        var FGWiki = function(options){
        };
        
        var bot = new MediaWiki.Bot();
        bot.settings.endpoint = "http://wiki.flightgear.org/api.php";
        bot.settings.byeline = "(using ContentMonster wiki bot)";
        bot.settings.rate = 100; // delay between requests in milliseconds

        FGWiki.prototype.login = function(username, password, onComplete, onError){
            console.log('Trying login with username "' + username + '"...');
            bot.login(username, password).complete(function(){
                console.log('Logged in successfully!');
                if (onComplete)
                    onComplete();
            }).error(function(err){
                console.log('Something went wrong: ' + err.toString());
                if (onError)
                    onError(err);
            })
        };

        FGWiki.prototype.logout = function(onComplete, onError){
            bot.logout().complete(function(){
                console.log('Logged out successfully');
                if (onComplete)
                    onComplete();
            }).error(function(err){
                console.log('Logout failed: ' + err.toString());
                if (onError)
                    onError(err);
            })
        };

        FGWiki.prototype.page = function(title, onComplete, onError){
            bot.page(title).complete(function(title, text, date){
                console.log('Page "' + title + '" fetched successfully! Last revision from ' + date + ' has ' + text.length + ' byte(s).');
                if (onComplete)
                    onComplete({
                        title: title,
                        text: text,
                        date: date
                    });
            }).error(function(err){
                console.log('Page fetch failed: ' + err.toString());
                if (onError)
                    onError(err);
            })            
        };

        return FGWiki;
    })();
    module.exports = FGWiki;
})();
