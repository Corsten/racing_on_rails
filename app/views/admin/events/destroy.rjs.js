page.visual_effect(:puff, "event_#{@event.id}_row", :duration => 2)
page.hide("warn")
page.show("notice")
page["notice_span"].replace_html "Deleted #{@event.name}"
