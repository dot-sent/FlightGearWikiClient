"use strict";

(function(){
    var MediaWiki = require("mediawiki");

    var FGWiki = (function(options){
        var FGWiki = function(options){

        };
        
        var bot = new MediaWiki.Bot();
        if (options === undefined)
            options = {};
        bot.settings.endpoint = options.endpoint || "http://wiki.flightgear.org/api.php";
        bot.settings.byeline = options.byeline || "(using ContentMonster wiki bot)";
        bot.settings.rate = options.rate || 100; // delay between requests in milliseconds

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
            });
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
            });
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
            });
        };

        FGWiki.prototype.history = function(title, count, onComplete, onError){
            bot.history(title, count).complete(function(title, history){
                console.log('History for page "' + title + '" fetched successfully! Entries: ' + history.length);
                if (onComplete)
                    onComplete({
                        title: title,
                        history: history
                    });
            }).error(function(err){
                console.log('History fetch failed: ' + err.toString());
                if (onError)
                    onError(err);
            });
        };

        FGWiki.prototype.revision = function(id, onComplete, onError){
            bot.revision(id).complete(function(title, text, date){
                console.log('Revision ' + id + ' fetched successfully!');
                if (onComplete)
                    onComplete({
                        title: title,
                        text: text,
                        date: date
                    });
            }).error(function(err){
                console.log('Revision fetch failed: ' + err.toString());
                if (onError)
                    onError(err);
            });
        };

        FGWiki.prototype.edit = function(title, text, summary, onComplete, onError){
            bot.edit(title, text, summary).complete(function(title, revision, date){
                console.log('Page "' + title + '" edited successfully! New revision ID: ' + revision);
                if (onComplete)
                    onComplete({
                        title: title,
                        text: text,
                        date: date
                    });
            }).error(function(err){
                console.log('Edit failed: ' + err.toString());
                if (onError)
                    onError(err);
            });
        };

        return FGWiki;
    })();
    module.exports = FGWiki;
})();
