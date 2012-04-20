$(window).ready ->
    $('span.field-with-errors').each (_, spanTag) ->
        field = $(spanTag).find('>input, >textarea')

        if field.attr('type') == 'file'
            errors = $('<ul/>').addClass('inline-errors').insertAfter(field)
            for attr in spanTag.attributes
                $('<li/>').text(attr.value).appendTo(errors) if attr.name == 'data-error'
        else
            tooltip = $('<ul/>').addClass('tooltip')
            for attr in spanTag.attributes
                $('<li/>').text(attr.value).appendTo(tooltip) if attr.name == 'data-error'

            field.qtip
                content:
                    text: tooltip.html()
                position:
                    my: 'top left'
                    at: 'right center'
                    target: field
                show:
                    target: field
                    event: 'focus'
                    solo: field.parent('form')
                hide:
                    target: field
                    event: 'blur'
                    fixed: true
                style:
                    classes: 'ui-tooltip-red ui-tooltip-shadow ui-tooltip-rounded'

            field.hover (->
                tooltip.fadeIn()
            ), ->
                tooltip.fadeOut()
