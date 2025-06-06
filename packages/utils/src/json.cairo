use game_components_minigame::models::settings::GameSetting;
use game_components_metagame::models::context::GameContext;
use graffiti::json::JsonImpl;

pub fn create_settings_json(name: ByteArray, description: ByteArray, settings: Span<GameSetting>) -> ByteArray {
    let mut settings_json = JsonImpl::new();
    let mut settings_index = 0;
    loop {
        if settings_index == settings.len() {
            break;
        }
        let setting = settings.at(settings_index);
        settings_json = settings_json.add(setting.name.clone(), setting.value.clone());
        settings_index += 1;
    };
    let settings_json = settings_json.build();

    let metadata = JsonImpl::new()
        .add("Name", name)
        .add("Description", description)
        .add("Settings", settings_json)
        .build();

    metadata
}

pub fn create_objectives_json(objectives: Span<ByteArray>) -> ByteArray {
    let mut metadata = JsonImpl::new();
    let mut objective_index = 0;
    loop {
        if objective_index == objectives.len() {
            break;
        }
        let objective_name = format!("Objective {}", objective_index + 1);
        let objective_value = objectives.at(objective_index);
        metadata = metadata.add(objective_name, objective_value.clone());
        objective_index += 1;
    };
    metadata.build()
}

pub fn create_context_json(contexts: Span<GameContext>) -> ByteArray {
    let mut metadata = JsonImpl::new();
    let mut context_index = 0;
    loop {
        if context_index == contexts.len() {
            break;
        }
        let context = contexts.at(context_index);
        metadata = metadata.add(context.name.clone(), context.value.clone());
        context_index += 1;
    };
    metadata.build()
}

pub fn create_json_array(values: Span<ByteArray>) -> ByteArray {
    if values.len() == 0 {
        return "[]";
    }
    
    let mut result = "[";
    let mut index = 0;
    loop {
        if index == values.len() {
            break;
        }
        let value = values.at(index);
        result += "\"" + value.clone() + "\"";
        
        // Add comma if not the last element
        if index < values.len() - 1 {
            result += ",";
        }
        index += 1;
    };
    result += "]";
    result
}

#[cfg(test)]
mod tests {
    use super::create_settings_json;
    use super::create_objectives_json;
    use super::create_context_json;
    use super::create_json_array;

    use game_components_minigame::models::settings::GameSetting;
    use game_components_metagame::models::context::GameContext;

    #[test]
    fn test_settings_json() {
        let settings = array![
            GameSetting {
                name: "Test Setting 1",
                value: "Test Setting 1 Value",
            },
            GameSetting {
                name: "Test Setting 2",
                value: "Test Setting 2 Value",
            },
        ].span();
        let _current_1 = create_settings_json(
            "Test Settings",
            "Test Settings Description",
            settings,
        );

        println!("{}", _current_1);
    }

    #[test]
    fn test_objectives_json() {
        let objectives = array![
            "Score 100 points",
            "Kill 10 enemies",
        ].span();
        let _current_1 = create_objectives_json(objectives);
        println!("{}", _current_1);
    }

    #[test]
    fn test_contexts_json() {
        let contexts = array![
            GameContext { name: "Test Context 1", value: "Test Context 1 Value" },
            GameContext { name: "Test Context 2", value: "Test Context 2 Value" },
        ].span();
        let _current_1 = create_context_json(contexts);
        println!("{}", _current_1);
    }

    #[test]
    fn test_json_array() {
        let values = array![
            "Test Value 1",
            "Test Value 2",
        ].span();
        let _current_1 = create_json_array(values);
        println!("{}", _current_1);
    }
}
