module ComponentFactory
  def component_factory(elem)
    inner = elem.children.map(&:to_s).join
    # TODO:  Handle changed names
    transform_method = :"_transform_#{self.component_lookup[elem.name]}"
    if self.respond_to?(transform_method)
      REXML::Document.new(self.send(transform_method, elem, inner)).root
    else
      nil
    end
  end

  def _pass_through_attributes(elem)
    ignored = ['class', 'id', 'href', 'size', 'large', 'no-expander', 'small', 'target'];
    elem.attributes.map do |name, value|
      if ignored.include?(name.downcase)
        ''
      else
        "#{name}=\"#{value}\""
      end
    end.join(' ')
  end

  def _has_class(elem, klass)
    !!elem.attributes['class'] && elem.attributes['class'].split(' ').include?(klass)
  end

  def _class_array(elem, defaults = [])
    (elem.attributes['class'] ? (defaults.concat(elem.attributes['class'].split(' '))) : defaults).uniq
  end

  def _target_attribute(elem)
    elem.attributes['target'] ? " target=\"#{elem.attributes['target']}\"" : ''
  end

  def _transform_button(component, inner)
    expand = _has_class(component, 'expand')
    if component.attributes['href']
      target = _target_attribute(component)
      if expand
        inner = "<a href=\"#{component.attributes['href']}\"#{target} align=\"center\" class=\"float-center\">#{inner}</a>"
      else
        inner = "<a href=\"#{component.attributes['href']}\"#{target}>#{inner}</a>"
      end
    end
    inner = "<center>#{inner}</center>" if expand

    classes = _class_array(component, ['button'])
    if expand
      return "<table class=\"#{classes.join(' ')}\"><tr><td><table><tr><td>#{inner}</td></tr></table></td><td class=\"expander\"></td></tr></table>"
    else
      return "<table class=\"#{classes.join(' ')}\"><tr><td><table><tr><td>#{inner}</td></tr></table></td></tr></table>"
    end
  end

  def _transform_menu(component, inner)
    classes = _class_array(component, ['menu'])
    "<table class=\"#{classes.join(' ')}\"><tr><td><table><tr>#{inner}</tr></table></td></tr></table>"
  end

  def _transform_menu_item(component, inner)
    target = _target_attribute(component)
    "<th class=\"menu-item\"><a href=\"#{component.attributes['href']}\"#{target}>#{inner}</a></th>"
  end

  def _transform_container(component, inner)
    classes = _class_array(component, ['container'])
    "<table class=\"#{classes.join(' ')}\"><tbody><tr><td>#{inner}</td></tr></tbody></table>"
  end

  def _transform_row(component, inner)
    classes = _class_array(component, ['row'])
    attrs = _pass_through_attributes(component)
    "<table #{attrs} class=\"#{classes.join(' ')}\"><tbody><tr>#{inner}</tr></tbody></table>"
  end

  # in inky.js this is factored out into makeClumn.  TBD if we need that here.
  def _transform_columns(component, inner)

    col_count = component.parent.elements.size
    small_size = component.attributes['small'] || self.column_count
    large_size = component.attributes['large'] || component.attributes['small'] || (self.column_count / col_count).to_i

    classes = _class_array(component, ["small-#{small_size}", "large-#{large_size}", "columns"])


    classes.push('first') unless component.previous_element
    classes.push('last') unless component.next_element

    subrows = component.elements.to_a("//*[contains(@class,'row')]").concat(component.elements.to_a("//row"))
    expander = ''
    if large_size.to_i == self.column_count && subrows.size == 0
      expander = "<th class=\"expander\"></th>"
    end
    "<th class=\"#{classes.join(' ')}\"><table><tr><th>#{inner}</th>#{expander}</tr></table></th>"
  end

  def _transform_block_grid(component, inner)
    classes = _class_array(component, ['block-grid', "up-#{component.attributes['up']}"])
    "<table class=\"#{classes.join(' ')}\"><tr>#{inner}</tr></table>"
  end

  def _transform_center(component, inner)
    # NOTE:  Using children instead of elements because elements.to_a
    # sometimes appears to miss elements that show up in size
    component.elements.to_a.each do |child|
      child.add_attribute('align', 'center')
      child_classes = _class_array(child, ['float-center'])
      child.add_attribute('class', child_classes.join(' '))
      items = component.elements.to_a("//*[contains(@class,'menu-item')]").concat(component.elements.to_a("//item"))
      items.each do |item|
        item_classes = _class_array(item, ['float-center'])
        item.add_attribute('class', item_classes.join(' '))
      end
    end
    return component.to_s
  end

  def _transform_callout(component, inner)
    classes = _class_array(component, ['callout-inner'])
    return "<table class=\"callout\"><tr><th class=\"#{classes.join(' ')}\">#{inner}</th><th class=\"expander\"></th></tr></table>"
  end

  def _transform_spacer(component, inner)
    classes = _class_array(component, ['spacer'])
    size = component.attributes['size']
    size_sm = component.attributes['size-sm']
    size_lg = component.attributes['size-lg']
    if size_sm || size_lg
      html = ''
      if size_sm
        html += "<table class=\"#{classes.join(' ')} hide-for-large\"><tbody><tr><td height=\"#{size_sm}px\" style=\"font-size:#{size_sm}px;line-height:#{size_sm}px;\">&#xA0;</td></tr></tbody></table>"
      end
      if size_lg
        html += "<table class=\"#{classes.join(' ')} show-for-large\"><tbody><tr><td height=\"#{size_lg}px\" style=\"font-size:#{size_lg}px;line-height:#{size_lg}px;\">&#xA0;</td></tr></tbody></table>"
      end
      if size_sm && size_lg
        # REXML doesn't like replacing a single element with a double
        html = "<span>#{html}</span>"
      end
      return html
    else
      size ||= 16
      return "<table class=\"#{classes.join(' ')}\"><tbody><tr><td height=\"#{size}px\" style=\"font-size:#{size}px;line-height:#{size}px;\">&#xA0;</td></tr></tbody></table>"
    end
  end

  def _transform_wrapper(component, inner)
    classes = _class_array(component, ['wrapper'])
    return "<table class=\"#{classes.join(' ')}\" align=\"center\"><tr><td class=\"wrapper-inner\">#{inner}</td></tr></table>"
  end
end
