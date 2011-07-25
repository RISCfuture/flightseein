/*
 **  jquery.text.js -- Utilitaires sur l'utilisation de TextNode
 **  Copyright (c) 2007 France Telecom
 **  Julien Wajsberg <julien.wajsberg@orange-ftgroupe.com>
 **
 **  Projet Siclome
 **
 **  $LastChangedDate$
 **  $LastChangedRevision$
 */

(function($) {
    /* jQuery object extension methods */
    $.fn.extend({
                    appendText: function(e) {
                        if (typeof e == "string")
                            return this.append(document.createTextNode(e));
                        return this;
                    }
                });


})(jQuery);
