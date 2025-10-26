final _regex = RegExp(r'[-:]');

String nameForVar(String name) => '__coal_${name.replaceAll(_regex, '_')}';
